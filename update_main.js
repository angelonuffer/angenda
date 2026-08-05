const fs = require('fs');
let code = fs.readFileSync('fonte/Main.elm', 'utf8');

// For Tasks (has `date = ... }`)
code = code.replace(/(\s*, date = [^}]+)(\s*})/g, '$1\n                                    , updatedAt = 0$2');

// For Routines (has `selectedDays = ... }`)
code = code.replace(/(\s*, selectedDays = [^}]+)(\s*})/g, '$1\n                                    , updatedAt = 0$2');

// For Plans (has `deadline = ... }`)
code = code.replace(/(\s*, deadline = [^}]+)(\s*})/g, '$1\n                                    , updatedAt = 0$2');

fs.writeFileSync('fonte/Main.elm', code);
