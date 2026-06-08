package be.api;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.databind.ObjectMapper;

import be.business.AIService;
import be.business.GradeService;
import be.business.PromptBuilder;
import be.business.StudentQueryService;
import be.business.dtos.AIQuery;
import be.business.dtos.AIResponse;
import be.business.dtos.ChatRequest;
import be.business.dtos.StudentGrade;

@RestController
@RequestMapping("/ai")
public class AIController {

    private final AIService aiService;
    private final PromptBuilder promptBuilder;
    private final StudentQueryService queryService;
    private final GradeService gradeService;

    private final ObjectMapper mapper = new ObjectMapper();

    public AIController(AIService aiService,
                        PromptBuilder promptBuilder,
                        StudentQueryService queryService,
                        GradeService gradeService) {
        this.aiService = aiService;
        this.promptBuilder = promptBuilder;
        this.queryService = queryService;
        this.gradeService = gradeService;
    }

    @PostMapping("/chat")
    public Object chat(@RequestBody ChatRequest body) {

        try {
            String aiRaw = aiService.askLLama(
        promptBuilder.buildPrompt(body.getMessage())
);

            String json = extractJson(aiRaw);

            AIResponse ai = mapper.readValue(json, AIResponse.class);

            Map<String, List<StudentGrade>> classes =
                    gradeService.getLatestClasses();

            if (classes == null || classes.isEmpty())
                return "Chưa có dữ liệu Excel";

            List<StudentGrade> all = new ArrayList<>();
            classes.values().forEach(all::addAll);

            // ===== AGGREGATE =====
            if ("aggregate".equalsIgnoreCase(ai.getType())) {

                List<StudentGrade> result =
                        queryService.aggregate(all, ai.getField(), ai.getAggregate());

                return filterByClass(result, ai.getClassName());
            }

            // ===== FILTER =====
            AIQuery q = new AIQuery();
            q.setField(ai.getField());
            q.setOperator(ai.getOperator());
            q.setValue(ai.getValue());

            List<StudentGrade> result = queryService.filter(all, q);

            return filterByClass(result, ai.getClassName());

        } catch (Exception e) {
            return "AI lỗi: " + e.getMessage();
        }
    }

    private List<StudentGrade> filterByClass(List<StudentGrade> list, String className) {

        if (className == null || className.isBlank()) return list;

        return list.stream()
                .filter(s -> s.getClassName() != null &&
                        s.getClassName().equalsIgnoreCase(className))
                .toList();
    }

    private String extractJson(String text) {

        int start = text.indexOf("{");
        int end = text.lastIndexOf("}");

        if (start == -1 || end == -1 || end <= start)
            throw new RuntimeException("AI không trả JSON");

        return text.substring(start, end + 1);
    }
}