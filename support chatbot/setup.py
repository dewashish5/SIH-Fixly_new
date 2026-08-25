from setuptools import setup, find_packages

setup(
    name="gig-support-chatbot",
    version="1.0.0",
    description="Independent Multi-Language Support Chatbot Module for Gig Worker Community Platforms",
    author="Google Deepmind Team",
    packages=find_packages(),
    include_package_data=True,
    package_data={
        "gig_support_chatbot": [
            "widget/*.js",
            "widget/*.css",
        ],
    },
    install_requires=[],
    extras_require={
        "test": ["pytest", "pytest-cov"],
    },
    python_requires=">=3.8",
    classifiers=[
        "Programming Language :: Python :: 3",
        "Operating System :: OS Independent",
    ],
)
