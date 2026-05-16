package org.example.controller;

import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.map.IMap;
import jakarta.annotation.PostConstruct;
import org.example.User;
import org.example.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = {
        "http://localhost:3000",
        "http://localhost:5173"
})

@RestController
@RequestMapping("/api")
public class UserController {

    @Autowired
    private HazelcastInstance hazelcast;

    @PostMapping("/put")
    public String put() {
        IMap<String, String> map = hazelcast.getMap("test");
        map.put("hello", "from-react");
        return "ok";
    }

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
