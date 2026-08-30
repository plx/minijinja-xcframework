import MiniJinjaC

guard let environment = mj_env_new() else {
  fatalError("mj_env_new returned nil")
}
defer { mj_env_free(environment) }

var context = mj_value_new_none()
let rendered = "Hello from {{ 6 * 7 }}!".withCString { source in
  "host-smoke".withCString { name in
    mj_env_render_named_str(environment, name, source, context)
  }
}

guard let rendered else {
  fatalError("MiniJinja render failed")
}
defer { mj_str_free(rendered) }

let result = String(cString: rendered)
precondition(result == "Hello from 42!", "unexpected render result: \(result)")
print(result)
