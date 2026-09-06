package com.lab.server_1.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

import com.lab.server_1.dto.HomePageResponse;
import com.lab.server_1.dto.Server2Response;
import com.lab.server_1.dto.Server3Response;
import com.lab.server_1.dto.Server4Response;

@RestController
public class HomePageController {

    private final RestClient server2Client;

    private final RestClient server3Client;

    private final RestClient server4Client;

    public HomePageController(@Value("${server2.base-url}") String server2Url,
            @Value("${server3.base-url}") String server3Url,
            @Value("${server4.base-url}") String server4Url) {
        this.server2Client = RestClient.create(server2Url);
        this.server3Client = RestClient.create(server3Url);
        this.server4Client = RestClient.create(server4Url);
    }

    @GetMapping("/home")
    public HomePageResponse homeDetails(@RequestParam("itemId") String itemId) {

        Server2Response s2 = server2Client.get()
                .uri("/compute")
                .retrieve()
                .body(Server2Response.class);

        Server3Response s3 = server3Client.get()
                .uri("/data?itemId={itemId}", itemId)
                .retrieve()
                .body(Server3Response.class);

        Server4Response s4 = server4Client.get()
                .uri("/user-details?userId={userId}", "U1")
                .retrieve()
                .body(Server4Response.class);

        return new HomePageResponse(s2.score(), s3.name(), s4.userId());
    }
}
