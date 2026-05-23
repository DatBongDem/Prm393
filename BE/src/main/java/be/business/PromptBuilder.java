package be.business;

import org.springframework.stereotype.Component;

@Component
public class PromptBuilder {

    public String buildPrompt(String userQuestion) {

        return """
You are an AI that converts Vietnamese questions into JSON query for a student grade system.

IMPORTANT RULES:
- You MUST return ONLY JSON.
- No explanation, no text, no markdown.
- If question is unrelated to student grades → return type = "irrelevant".

AVAILABLE FIELDS:
- project   (điểm dự án)
- finalExam (điểm thi cuối kỳ)
- total     (điểm tổng)
- result    (PASS / FAIL)

JSON FORMAT:

Filter:
{
  "type":"filter",
  "field":"total",
  "operator":">",
  "value":"5"
}

Aggregate:
{
  "type":"aggregate",
  "field":"project",
  "aggregate":"max"
}

Irrelevant:
{
  "type":"irrelevant"
}

Vietnamese examples:

"ai có điểm dự án cao nhất"
→
{
  "type":"aggregate",
  "field":"project",
  "aggregate":"max"
}

"sinh viên có tổng dưới 5"
→
{
  "type":"filter",
  "field":"total",
  "operator":"<",
  "value":"5"
}

"xin chào"
→
{
  "type":"irrelevant"
}

USER QUESTION:
""" + userQuestion;
    }
}