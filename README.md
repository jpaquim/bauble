# [Bauble](https://bauble.studio)

Bauble is a toy for composing signed distance functions in a high-level language ([Janet](https://janet-lang.org/)), compiling them to [GLSL](https://www.khronos.org/opengl/wiki/OpenGL_Shading_Language), and rendering them via WebGL.

Bauble is still in its early days, but it's progressed to the point that you can do some pretty neat stuff with it. Try it out at <https://bauble.studio/>, or watch this video introduction where I model an infinite number of hot air balloons:

[![Livecoding a hot air balloon (1/3)](https://img.youtube.com/vi/0-OtdjiR7dc/maxresdefault.jpg)](https://www.youtube.com/watch?v=0-OtdjiR7dc&list=PLjT5GDnW_UMBS6ih0kG7jWB0n1SnotnEu)

For more examples, I sometimes tweet videos of Bauble's development:

- [bounding surfaces](https://twitter.com/ianthehenry/status/1567709580792315904)
- [instanced repetition](https://twitter.com/ianthehenry/status/1566583962989842432)
- [animation](https://twitter.com/ianthehenry/status/1566081717592502274)
- [procedural distortion](https://twitter.com/ianthehenry/status/1565575515016085504)
- [non-rigid deformations](https://twitter.com/ianthehenry/status/1559778903324954624)
- [announcement](https://twitter.com/ianthehenry/status/1559049547099254785)
- [surfaces](https://twitter.com/ianthehenry/status/1557881955156275200)
- [shapes](https://twitter.com/ianthehenry/status/1554729639183937536)
- [first ever demo](https://twitter.com/ianthehenry/status/1551422839307190272)

# Dependencies

- [`emscripten`](https://emscripten.org/)

# Development

To build Bauble, all you have to do is run:

```
$ ./build.sh
```

To create an optimized build, use:

```
$ BUILD_MODE=prod ./build.sh
```

# Known bugs

- [ ] Bauble will cast and calculate lights even for shaders that don't need lights, making it slower than it needs to be in the default RGB-normal shading view.
