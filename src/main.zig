const std = @import("std");
const gl = @import("headers/glfw.zig");

const Vertex = struct {
    position: @Vector(3, f32),
    color: @Vector(3, f32),
};

pub fn main() !void {
    _ = gl.glfwInit();
    defer gl.glfwTerminate();

    gl.glfwWindowHint(gl.GLFW_CONTEXT_VERSION_MAJOR, 3);
    gl.glfwWindowHint(gl.GLFW_CONTEXT_VERSION_MINOR, 3);
    gl.glfwWindowHint(gl.GLFW_OPENGL_PROFILE, gl.GLFW_OPENGL_CORE_PROFILE);

    const window = gl.glfwCreateWindow(800, 600, "Hello World Window", null, null);
    defer gl.glfwDestroyWindow(window);

    gl.glfwMakeContextCurrent(window);

    gl.glViewport(0, 0, 800 * 2, 600 * 2);

    var vertices = [_]Vertex{
        .{
            .position = .{ -0.5, -0.5, 0.0 },
            .color = .{ 1.0, 0.0, 0.0 },
        },
        .{
            .position = .{ 0.5, -0.5, 0.0 },
            .color = .{ 0.0, 1.0, 0.0 },
        },
        .{
            .position = .{ 0.0, 0.5, 0.0 },
            .color = .{ 0.0, 0.0, 1.0 },
        },
        .{
            .position = .{ -0.5, 0.5, 0.0 },
            .color = .{ 1.0, 0.0, 1.0 },
        },
    };

    var vbo: gl.GLuint = 0;
    gl.glGenBuffers(1, &vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(Vertex) * vertices.len, &vertices, gl.GL_STREAM_DRAW);

    var vao: gl.GLuint = 0;
    gl.glGenVertexArrays(1, &vao);
    gl.glBindVertexArray(vao);
    const stride = @sizeOf(Vertex);
    const color_offset: *anyopaque = @ptrFromInt(@offsetOf(Vertex, "color"));

    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, stride, null);
    gl.glEnableVertexAttribArray(0);

    gl.glVertexAttribPointer(1, 3, gl.GL_FLOAT, gl.GL_FALSE, stride, color_offset);
    gl.glEnableVertexAttribArray(1);

    const vertex_source = @embedFile("shaders/triangle.vert");
    const fragment_source = @embedFile("shaders/triangle.frag");
    const vert_program = try compileShaders(vertex_source, gl.GL_VERTEX_SHADER);
    const frag_program = try compileShaders(fragment_source, gl.GL_FRAGMENT_SHADER);
    defer gl.glDeleteShader(vert_program);
    defer gl.glDeleteShader(frag_program);

    const program = gl.glCreateProgram();
    defer gl.glDeleteProgram(program);

    gl.glAttachShader(program, vert_program);
    gl.glAttachShader(program, frag_program);
    gl.glLinkProgram(program);

    const utime_handle = gl.glGetUniformLocation(program, "utime");

    var delta_time: f32 = 0;
    var elapsed_time: f32 = 0;
    while (gl.glfwWindowShouldClose(window) == 0) {
        const time_stamp_start: i128 = std.time.nanoTimestamp();

        gl.glClearColor(0.07, 0.13, 0.17, 1);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        gl.glUseProgram(program);
        gl.glBindVertexArray(vao);
        gl.glDrawArrays(gl.GL_TRIANGLE_FAN, 0, 4);

        gl.glfwSwapBuffers(window);
        gl.glfwPollEvents();

        const time_stamp_end: i128 = std.time.nanoTimestamp();
        delta_time = @as(f32, @floatFromInt(time_stamp_end - time_stamp_start)) / @as(f32, @floatFromInt(std.time.ns_per_s));
        elapsed_time += delta_time;

        rotateVertices(&vertices, delta_time * 0.5);
        gl.glBufferSubData(gl.GL_ARRAY_BUFFER, 0, @sizeOf(Vertex) * vertices.len, &vertices);
        gl.glUniform1f(utime_handle, elapsed_time);
    }
}

fn rotateVertices(vertices: []Vertex, angle: f32) void {
    for (vertices) |*vertex| {
        const x = vertex.position[0];
        const y = vertex.position[1];
        vertex.position[0] = x * std.math.cos(angle) - y * std.math.sin(angle);
        vertex.position[1] = x * std.math.sin(angle) + y * std.math.cos(angle);
    }
}

fn compileShaders(source: [*c]const u8, shader_type: u32) error{CompileFailed}!u32 {
    const shader_program = gl.glCreateShader(shader_type);
    gl.glShaderSource(shader_program, 1, &source, null);
    gl.glCompileShader(shader_program);

    var success: i32 = 0;
    gl.glGetShaderiv(shader_program, gl.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        var log = std.mem.zeroes([512]u8);
        gl.glGetShaderInfoLog(shader_program, log.len, null, &log);
        std.debug.print("Compile error: {s}\n", .{log});
        return error.CompileFailed;
    }

    return shader_program;
}
