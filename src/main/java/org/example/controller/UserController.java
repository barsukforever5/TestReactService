package org.example.controller;

import jakarta.annotation.PostConstruct;
import org.example.User;
import org.example.UserService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class UserController {

    private final UserService service;

    public UserController(UserService service) {
        this.service = service;
    }

    @PostConstruct
    public void init() {
        System.out.println("USER CONTROLLER LOADED");
    }

    @GetMapping("/users")
    public List<User> list() {
        return service.findAll();
    }

    @PostMapping("/users/create")
    public User create(@RequestBody User user) {
        System.out.println("USER CREATE IS CALLED");
        User u = service.create(user);
        System.out.println("USER : " + u);
        return u;
    }

    @DeleteMapping("/users/{key}")
    public void delete(@PathVariable String key) {
        System.out.println("USER DELETE IS CALLED : " + key);
        service.delete(key);
    }

    @PutMapping("/users/{key}")
    public void update(@PathVariable String key, @RequestBody User user) {
        System.out.println("USER UPDATE IS CALLED : " + key);
        service.update(key, user);
    }
}
