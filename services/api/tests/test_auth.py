def test_register_login_me(client):
    r = client.post(
        "/v1/auth/register",
        json={"email": "Fan@Example.com", "full_name": "Fete Fan", "password": "soca-2027!"},
    )
    assert r.status_code == 201

    r = client.post("/v1/auth/login", json={"email": "fan@example.com", "password": "soca-2027!"})
    assert r.status_code == 200
    token = r.json()["access_token"]

    r = client.get("/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert r.json()["email"] == "fan@example.com"


def test_duplicate_email_rejected(client):
    body = {"email": "a@b.com", "full_name": "A", "password": "password123"}
    assert client.post("/v1/auth/register", json=body).status_code == 201
    assert client.post("/v1/auth/register", json=body).status_code == 409


def test_wrong_password_and_missing_token(client):
    client.post(
        "/v1/auth/register", json={"email": "c@d.com", "full_name": "C", "password": "password123"}
    )
    r = client.post("/v1/auth/login", json={"email": "c@d.com", "password": "wrong-password"})
    assert r.status_code == 401
    assert client.get("/v1/auth/me").status_code == 401
