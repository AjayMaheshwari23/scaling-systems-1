package com.lab.server_4.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import com.lab.server_4.dto.UserDetailsRequest;
import com.lab.server_4.dto.UserDetailsResponse;

@RestController
public class UserDetailsController {

    @GetMapping("/user-details")
    public UserDetailsResponse userDetails(UserDetailsRequest request) {
        return new UserDetailsResponse(request.userId(), "Ajay Maheshwari");
    }
}
