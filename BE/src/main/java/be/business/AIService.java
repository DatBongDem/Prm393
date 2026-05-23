package be.business;

import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Service
public class AIService {

    private final WebClient webClient;

    public AIService() {
        this.webClient = WebClient.builder()
                .baseUrl("http://localhost:11434")
                .build();
    }

    public String askLLama(String prompt) {

        try {
            Map response = webClient.post()
                    .uri("/api/generate")
                    .bodyValue(Map.of(
                            "model", "qwen2.5:7b",
                            "prompt", prompt,
                            "stream", false,
                            "temperature", 0
                    ))
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block(); // ⭐ giờ sẽ chạy OK

            if (response == null) return "AI ERROR";

            return response.get("response").toString();

        } catch (Exception e) {
            e.printStackTrace();
            return "AI ERROR";
        }
    }
}