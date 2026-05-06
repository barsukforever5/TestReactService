import { useEffect, useState } from "react";

const API = "http://localhost:8081/api/users";

function App() {
  const [users, setUsers] = useState([]);
  const [name, setName] = useState("");
  const [age, setAge] = useState("");

  const [editingKey, setEditingKey] = useState(null);

  // 📥 загрузка пользователей
  const loadUsers = async () => {
    const res = await fetch(API);
    const data = await res.json();
    setUsers(data);
  };

  useEffect(() => {
    loadUsers();
  }, []);

  // ➕ создать или обновить
  const saveUser = async () => {
    if (!name || !age) return;

    if (editingKey) {
      // UPDATE
      await fetch(`${API}/${editingKey}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, age: Number(age) }),
      });
    } else {
      // CREATE
      await fetch(API, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, age: Number(age) }),
      });
    }

    setName("");
    setAge("");
    setEditingKey(null);
    loadUsers();
  };

  // ❌ удалить
  const deleteUser = async (key) => {
    await fetch(`${API}/${key}`, {
      method: "DELETE",
    });
    loadUsers();
  };

  // ✏️ начать редактирование
  const startEdit = (user) => {
    setName(user.name);
    setAge(user.age);
    setEditingKey(user.key);
  };

  return (
    <div style={{ padding: 20 }}>
      <h1>User CRUD</h1>

      {/* форма */}
      <div style={{ marginBottom: 20 }}>
        <input
          placeholder="name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />

        <input
          placeholder="age"
          value={age}
          onChange={(e) => setAge(e.target.value)}
        />

        <button onClick={saveUser}>
          {editingKey ? "Update" : "Add"}
        </button>

        {editingKey && (
          <button onClick={() => {
            setEditingKey(null);
            setName("");
            setAge("");
          }}>
            Cancel
          </button>
        )}
      </div>

      {/* список */}
      <ul>
        {users.map((u) => (
          <li key={u.key}>
            {u.name} ({u.age})

            <button onClick={() => startEdit(u)}>
              Edit
            </button>

            <button onClick={() => deleteUser(u.key)}>
              Delete
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;