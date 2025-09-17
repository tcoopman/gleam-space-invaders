pub type Callback =
  fn(Float) -> Nil

@external(javascript, "./engine_ffi.mjs", "request_animation_frame")
pub fn request_animation_frame(callback: Callback) -> Nil
