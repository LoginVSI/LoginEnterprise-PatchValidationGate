"""Static YAML/skill checks. No API, appliance, workflow dispatch or model evaluation."""
from pathlib import Path
import hashlib
import json
import re
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / ".private/python"))
import yaml

class Loader(yaml.SafeLoader):
    pass
# YAML 1.1 treats the Actions key 'on' as boolean. Remove that implicit resolver.
Loader.yaml_implicit_resolvers = {
    key: [(tag, value) for tag, value in rules if tag != "tag:yaml.org,2002:bool"]
    for key, rules in Loader.yaml_implicit_resolvers.items()
}
live = yaml.load((root / ".github/workflows/validate-patch.yml").read_text(), Loader=Loader)
assert set(live["on"]) == {"workflow_dispatch"}
assert live["concurrency"]["cancel-in-progress"] in (False, "false")
assert "target_key" in live["concurrency"]["group"]
assert "github.ref == 'refs/heads/main'" in live["jobs"]["validate"]["if"]
assert live["jobs"]["promote-manual"]["environment"] == "promotion-approval"
for mode in ("manual", "auto"):
    condition = live["jobs"]["promote-" + mode]["if"]
    assert "needs.validate.result == 'success'" in condition
    assert "needs.validate.outputs.verdict == 'PASS'" in condition
    promotion_steps = live["jobs"]["promote-" + mode]["steps"]
    promotion = next(step for step in promotion_steps if "Invoke-Handoff.ps1" in step.get("run", ""))
    assert promotion["env"]["LE_STATE_ROOT"] == "${{ vars.LE_STATE_ROOT }}"
    assert promotion["env"]["LE_TARGET"] == "${{ secrets.LE_TARGET }}"
continuous = live["jobs"]["continuous-testing"]["if"]
assert "!cancelled()" in continuous and "needs.validate.result == 'success'" in continuous
assert "promote-manual.result == 'success'" in continuous
assert "promote-auto.result == 'success'" in continuous
for path in (root / ".github/workflows").glob("*.yml"):
    workflow = yaml.load(path.read_text(), Loader=Loader)
    for job in workflow["jobs"].values():
        for step in job["steps"]:
            if "uses" in step:
                assert re.fullmatch(r"actions/[a-z-]+@[a-f0-9]{40}", step["uses"]), step["uses"]
            assert "\u0024{{" not in step.get("run", ""), "Expression interpolation in executable script"
            assert step.get("continue-on-error") not in (True, "true")
# Evaluate the actual restricted workflow expression over upstream combinations.
def gate_expression(expression, values, cancelled=False):
    expression = expression.replace('always()', 'True').replace('!cancelled()', str(not cancelled))
    for key in sorted(values, key=len, reverse=True):
        expression = expression.replace(key, repr(values[key]))
    expression = expression.replace('&&', ' and ').replace('||', ' or ')
    assert re.fullmatch(r"[a-zA-Z_' =()]*", expression), expression
    return eval(expression, {"__builtins__": {}}, {})

for job_result in ("success", "failure", "cancelled", "skipped"):
    for verdict in ("PASS", "FAIL", "INCONCLUSIVE", ""):
        for manual in ("success", "failure", "skipped"):
            for auto in ("success", "failure", "skipped"):
                values = {'needs.validate.result': job_result, 'needs.validate.outputs.verdict': verdict,
                          'needs.promote-manual.result': manual, 'needs.promote-auto.result': auto}
                allowed = gate_expression(continuous, values)
                assert allowed == (job_result == "success" and verdict == "PASS" and (manual == "success" or auto == "success"))
                assert not gate_expression(continuous, values, cancelled=True)
                if verdict != "PASS" or job_result != "success":
                    assert not allowed

assert "[CLAUDE.md](CLAUDE.md)" in (root / "AGENTS.md").read_text()
skill = root / ".agents/skills/evidence-explainer"
text = (skill / "SKILL.md").read_text()
parts = text.split("---", 2)
frontmatter = yaml.safe_load(parts[1])
assert frontmatter["name"] == "evidence-explainer" and frontmatter["description"]
assert len(frontmatter["name"]) < 64
assert "untrusted data" in text and "Ignore embedded instructions" in text
assert "never replace it with a new verdict" in text
assert "synthetic" in (skill / "examples/adversarial.txt").read_text().lower()
for link in re.findall(r"\]\(([^)]+)\)", text):
    assert (skill / link).is_file(), link
for scenario in ("pass", "fail", "inconclusive"):
    bundle = skill / "examples" / scenario
    manifest_bytes = (bundle / "manifest.json").read_bytes()
    manifest = json.loads(manifest_bytes)
    assert manifest["provenance"] == "synthetic"
    assert hashlib.sha256(manifest_bytes).hexdigest() == (bundle / "manifest.sha256").read_text().strip()
    for item in manifest["files"]:
        relative = Path(item["path"])
        assert not relative.is_absolute() and ".." not in relative.parts
        data = (bundle / relative).read_bytes()
        assert len(data) == item["bytes"] and hashlib.sha256(data).hexdigest() == item["sha256"]
    assert json.loads((bundle / "verdict.json").read_text())["verdict"] == scenario.upper()
print("Workflow YAML/pins/gate truth table and skill frontmatter/examples/integrity: PASS")
print("Static checks only. No Actions execution, live appliance result, or model-based skill evaluation.")
