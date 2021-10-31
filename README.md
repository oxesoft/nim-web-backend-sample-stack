Nim Web Backend Sample Stack
=====================================
This project aims to speed up the development of a web backend written in [Nim](https://nim-lang.org/) using [Prologue](https://planety.github.io/prologue/) + [Norm](https://norm.nim.town/), with the more common needs addressed. Both the Web Framework and ORM chosen are the most popular at the time of this implementation.

Notes
-----
1. This sample code uses SQLite as database backend however Norm also supports PostgreSQL;
2. Using this project as starting point *absolutely not* exempt you of reading [all](https://nim-lang.org/) of the material that you can before start coding using Nim;
3. VSCode is the suggested code editor. You just need to install the extension from the Marketplace.

Setup
-----
1. Follow the [official instructions for installing Nim](https://nim-lang.org/install.html);
2. Run `nimble build`;
3. Define an environment variable DATABASE_URL pointing to a file to be created (our SQLite database);
4. Call `./backend` and open in your browser the URL shown at the console.
