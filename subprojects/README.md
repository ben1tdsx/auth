# Subprojects

This directory is for additional Node.js projects that you want to organize alongside the cookie session manager project.

## Structure

Each subproject should be in its own directory with its own `package.json`:

```
subprojects/
├── project1/
│   ├── package.json
│   └── ...
├── project2/
│   ├── package.json
│   └── ...
└── ...
```

## Usage

1. Create a new directory for your project:
   ```bash
   mkdir subprojects/my-new-project
   cd subprojects/my-new-project
   ```

2. Initialize a new Node.js project:
   ```bash
   npm init -y
   ```

3. Install dependencies and start developing!

## Note

Each project in this directory is independent and has its own `package.json` and `node_modules` directory.

