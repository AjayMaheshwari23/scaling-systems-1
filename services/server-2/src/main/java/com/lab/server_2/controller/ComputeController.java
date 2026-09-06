package com.lab.server_2.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import com.lab.server_2.dto.ComputeResponse;

@RestController
public class ComputeController {

    @Value("${server2.work.factor}")
    private int workFactor;

    @GetMapping("/compute")
    public ComputeResponse compute() {

        long ans = 51966;
        for (int i = 0; i < workFactor; i++) {
            ans = (ans * 31 + i) & 0x7fffffff;
        }
        return new ComputeResponse(ans);
    }
}
