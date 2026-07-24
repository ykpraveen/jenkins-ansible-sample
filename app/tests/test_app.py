import importlib


def _reload_app(monkeypatch, **env):
    monkeypatch.delenv("SIMULATE_FAILURE", raising=False)
    monkeypatch.delenv("APP_VERSION", raising=False)
    monkeypatch.delenv("GIT_SHA", raising=False)
    for key, value in env.items():
        monkeypatch.setenv(key, value)

    import app as app_module

    importlib.reload(app_module)
    return app_module.app.test_client()


def test_health_ok(monkeypatch):
    client = _reload_app(monkeypatch)
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_health_simulated_failure(monkeypatch):
    client = _reload_app(monkeypatch, SIMULATE_FAILURE="true")
    resp = client.get("/health")
    assert resp.status_code == 500
    assert resp.get_json() == {"status": "unhealthy"}


def test_version_defaults(monkeypatch):
    client = _reload_app(monkeypatch)
    resp = client.get("/version")
    assert resp.status_code == 200
    assert resp.get_json() == {"version": "dev", "git_sha": "unknown"}


def test_version_from_env(monkeypatch):
    client = _reload_app(monkeypatch, APP_VERSION="1.2.3", GIT_SHA="abcdef0")
    resp = client.get("/version")
    assert resp.status_code == 200
    assert resp.get_json() == {"version": "1.2.3", "git_sha": "abcdef0"}
