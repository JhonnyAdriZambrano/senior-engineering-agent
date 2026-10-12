---
type: regex
pattern: "^\\{\"type\":\"assistant\"[^\\n]*?\"type\":\"text\",\"text\":\"(?:[^\"\\\\]|\\\\.)*?\\[(?:VERIFIED FACT|INFERENCE|TECHNICAL RECOMMENDATION|UNCERTAINTY / NEEDS VERIFICATION|REQUIRED FOR THE TASK|RECOMMENDED IMPROVEMENT|OUT-OF-SCOPE FINDING)\\]"
flags: "m"
target: "trace"
arm: "with-only"
---
