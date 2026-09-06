package com.lab.server_3.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.lab.server_3.dto.HomeDetailsResponse;

import java.util.Optional;

import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.simple.JdbcClient;

@RestController
public class HomeItemController {

    private final JdbcClient jdcbClient;

    public HomeItemController(JdbcClient jdcbClient) {
        this.jdcbClient = jdcbClient;
    }

    @GetMapping("/data")
    public ResponseEntity<HomeDetailsResponse> homeDetailsResponse(@RequestParam("itemId") Long itemId) {
        return jdcbClient.sql("SELECT id, name, value FROM home_item WHERE id = :id")
                .param("id", itemId)
                .query((rs, rowNum) -> new HomeDetailsResponse(
                        rs.getLong("id"), rs.getString("name"), rs.getString("value")))
                .optional()
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
