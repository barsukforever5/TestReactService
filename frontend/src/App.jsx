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
    console.log('load_Users:', res);

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
      await fetch(`${API}/create`, {
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
          style={{ marginLeft: 10 }}
        />

        <button onClick={saveUser} style={{ marginLeft: 10 }}>
          {editingKey ? "Update" : "Add"}
        </button>

        {editingKey && (
          <button
            onClick={() => {
              setEditingKey(null);
              setName("");
              setAge("");
            }}
            style={{ marginLeft: 10 }}
          >
            Cancel
          </button>
        )}
      </div>

      {/* таблица */}
      <table
        style={{
          width: "100%",
          borderCollapse: "collapse",
          marginTop: 20,
        }}
      >
        <thead>
          <tr>
            <th style={th}>Name</th>
            <th style={th}>Age</th>
            <th style={th}>Key</th>
            <th style={th}>Actions</th>
          </tr>
        </thead>

        <tbody>
          {users.map((u) => (
            <tr key={u.key}>
              <td style={td}>{u.name}</td>
              <td style={td}>{u.age}</td>
              <td style={td}>{u.key}</td>

              <td style={td}>
                <button onClick={() => startEdit(u)}>Edit</button>

                <button
                  onClick={() => deleteUser(u.key)}
                  style={{ marginLeft: 10 }}
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

const th = {
  border: "1px solid #ccc",
  padding: "8px",
  background: "#f5f5f5",
  textAlign: "left",
};

const td = {
  border: "1px solid #ccc",
  padding: "8px",
};

export default App;