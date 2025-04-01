#version 150

#ifdef VERTEX
    // Vertex shader code
    in vec2 position;
    in vec2 texcoord;
    out vec2 Texcoord;
    
    void main()
    {
        Texcoord = texcoord;
        Texcoord.y = 1.0 - texcoord.y;
        gl_Position = vec4(position, 0.0, 1.0);
    }
#else
    // Fragment shader code
    in vec2 Texcoord;
    out vec4 out_colour;
    
    void main() {
        out_colour = vec4(1.0, 0.0, 0.0, 1.0); // output a solid red
    }
#endif
