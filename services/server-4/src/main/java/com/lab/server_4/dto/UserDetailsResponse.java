package com.lab.server_4.dto;

public class UserDetailsResponse {
    private final String userId;

    private final String name;

    public UserDetailsResponse(String userId, String name) {
        this.userId = userId;
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public String getUserId() {
        return userId;
    }
}
