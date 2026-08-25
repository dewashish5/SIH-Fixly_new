"""
Bilingual Keyword, Phrase, and Intent Matcher for English and Hindi.
"""

import re
from typing import List, Optional, Set, Tuple
from .types import FAQItem, Language, Role


STOP_WORDS = {
    "how", "to", "do", "i", "a", "an", "the", "in", "for", "of", "my", "is", "and", "or", "please",
    "what", "are", "can", "you", "with", "on", "at", "from", "by", "me", "want",
    "कैसे", "करें", "की", "का", "के", "में", "से", "पर", "और", "या", "है", "हैं", "मुझे", "अपना", "अपनी", "दिखाएं", "बताएं", "करना", "करनी"
}


def normalize_text(text: str) -> str:
    if not text:
        return ""
    text = text.lower()
    text = re.sub(r"[^\w\s\u0900-\u097F]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def tokenize(text: str) -> List[str]:
    norm = normalize_text(text)
    return [t for t in norm.split(" ") if len(t) > 0]


class IntentMatcher:
    def __init__(self):
        pass

    def match_faq(
        self,
        query: str,
        faqs: List[FAQItem],
        lang: Language = Language.ENGLISH,
        min_score: float = 0.50,
    ) -> Optional[Tuple[FAQItem, float]]:
        clean_query = normalize_text(query)
        if not clean_query:
            return None

        query_tokens = [t for t in tokenize(clean_query) if t not in STOP_WORDS]
        if not query_tokens:
            query_tokens = tokenize(clean_query)
        query_token_set = set(query_tokens)

        best_match: Optional[FAQItem] = None
        best_score = 0.0

        for faq in faqs:
            score = self.score_faq(clean_query, query_token_set, faq, lang)
            if score > best_score:
                best_score = score
                best_match = faq

        if best_match and best_score >= min_score:
            return (best_match, best_score)
        return None

    def score_faq(
        self,
        clean_query: str,
        query_tokens: Set[str],
        faq: FAQItem,
        lang: Language,
    ) -> float:
        primary_kws = faq.get_keywords(lang)
        fallback_kws = faq.get_keywords(Language.ENGLISH if lang == Language.HINDI else Language.HINDI)
        all_kws = primary_kws + fallback_kws
        title = normalize_text(faq.get_title(lang))

        # 1. Exact title
        if clean_query == title:
            return 1.0

        # 2. Title containment
        if len(clean_query) >= 4 and clean_query in title:
            return 0.96
        if len(title) >= 4 and title in clean_query:
            return 0.94

        max_score = 0.0

        for kw in all_kws:
            clean_kw = normalize_text(kw)
            if not clean_kw:
                continue

            # 3. Exact keyword match
            if clean_query == clean_kw:
                score = 0.99
                if score > max_score:
                    max_score = score
                continue

            kw_word_count = len(clean_kw.split())

            # 4. Keyword phrase contained in query
            if clean_kw in clean_query:
                coverage = len(clean_kw) / max(len(clean_query), 1)
                base = 0.85 if kw_word_count > 1 else 0.72
                score = base + (0.13 * coverage)
                if score > max_score:
                    max_score = score

            elif clean_query in clean_kw:
                coverage = len(clean_query) / max(len(clean_kw), 1)
                base = 0.70 if kw_word_count > 1 else 0.60
                score = base + (0.20 * coverage)
                if score > max_score:
                    max_score = score

            # 5. Jaccard token overlap
            kw_tokens = set([t for t in tokenize(clean_kw) if t not in STOP_WORDS])
            if not kw_tokens:
                kw_tokens = set(tokenize(clean_kw))

            if kw_tokens and query_tokens:
                intersection = query_tokens.intersection(kw_tokens)
                if intersection:
                    jaccard = len(intersection) / len(query_tokens.union(kw_tokens))
                    kw_coverage = len(intersection) / len(kw_tokens)
                    # Only score if there is meaningful overlap
                    if jaccard >= 0.25 or kw_coverage >= 0.6:
                        token_score = 0.30 + (0.40 * jaccard) + (0.25 * kw_coverage)
                        if token_score > max_score:
                            max_score = token_score

        return max_score
