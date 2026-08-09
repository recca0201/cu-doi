from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parent.parent


def load_script_module(module_name: str):
    module_path = SCRIPTS_DIR / f"{module_name}.py"
    spec = spec_from_file_location(module_name, module_path)
    module = module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module