import { Annotation } from "@langchain/langgraph";

export const agentState = Annotation.Root({
    userId: Annotation(),
    prompt: Annotation(),
    conversationId: Annotation(),
    language: Annotation(),
    category: Annotation(),
    bookingType: Annotation(),
    isEmergency: Annotation(),
    scheduledTime: Annotation(),
    workerId: Annotation(),
    workerName: Annotation(),
    workerRate: Annotation(),
    workers: Annotation(),
    isAutoAssign: Annotation(),
    problemDescription: Annotation(),
    addressLine: Annotation(),
    coordinates: Annotation(),
    step: Annotation(),
    action: Annotation(),
    intent: Annotation(),
    estimate: Annotation(),
    policy: Annotation(),
    booking: Annotation(),
    bookings: Annotation(),
    suggestedReplies: Annotation(),
    aiResponse: Annotation(),
    error: Annotation()
});

export default agentState;
