package com.lab.server_4.dto;

public class UserDetailsRequest {
    private final String userId;

    public UserDetailsRequest(String userId) {
        this.userId = userId;
    }

    public String userId() {
        return userId;
    }
}
