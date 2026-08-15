
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalize coordinates and sample Ghostty's core interface color
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 terminalColor = texture(iChannel0, uv);

    // STATIC NOISE: iTime removed so the grain stays completely still
    float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);

    // ADJUST GRAIN STRENGTH HERE (0.15 is strong but readable)
    float grainStrength = 0.0075; 

    // Mix the grain into the color channels
    terminalColor.rgb += (noise - 0.5) * grainStrength;

    // Output the final state back to the terminal
    fragColor = terminalColor;
}
