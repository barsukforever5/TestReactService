package org.example;

import com.arangodb.ArangoDB;
import com.arangodb.ArangoDatabase;
import com.arangodb.entity.BaseDocument;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class UserService {

    private final ArangoDB arangoDB;

    public UserService(ArangoDB arangoDB) {
        this.arangoDB = arangoDB;
    }

    private ArangoDatabase db() {
        return arangoDB.db("_system");
    }

    public List<User> findAll() {
        List<User> result = new ArrayList<>();

        db().query("FOR u IN users RETURN u", BaseDocument.class)
                .forEachRemaining(doc -> {
                    User u = new User();
                    u.setKey(doc.getKey());
                    u.setName((String) doc.getAttribute("name"));
                    Number age = (Number) doc.getAttribute("age");
                    if(age != null) {
                        u.setAge(age.intValue());
                    }
                    result.add(u);
                });

        return result;
    }

    public User create(User user) {
        String key = UUID.randomUUID().toString();
        BaseDocument doc = new BaseDocument(key);
        doc.addAttribute("name", user.getName());
        doc.addAttribute("age", user.getAge());

        db().collection("users").insertDocument(doc);
        System.out.println("DOC.GET_KEY : " + doc.getKey());

        user.setKey(doc.getKey());

        return user;
    }

    public void delete(String key) {
        db().collection("users").deleteDocument(key);
    }

    public void update(String key, User user) {
        System.out.println("UPDATE USER : " + key);
        db().collection("users").updateDocument(key, user);
    }
}
