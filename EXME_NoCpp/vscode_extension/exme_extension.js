const vscode = require('vscode');
const path = require('path');
const fs = require('fs');

function q(s) { return '"' + s.replace(/"/g, '\\"') + '"'; }

function compilerCommand() {
  if (process.platform === 'win32') {
    const local = process.env.LOCALAPPDATA
      ? path.join(process.env.LOCALAPPDATA, 'EXME', 'bin', 'exme.cmd')
      : null;
    if (local && fs.existsSync(local)) return q(local);
    return 'exme';
  }
  return 'exme';
}

async function currentExmeEditor() {
  const editor = vscode.window.activeTextEditor;
  if (!editor || !editor.document.fileName.toLowerCase().endsWith('.exme')) {
    vscode.window.showErrorMessage('Open an .exme file first.');
    return null;
  }
  await editor.document.save();
  return editor;
}

async function chooseOutput(title, saveLabel) {
  return vscode.window.showSaveDialog({ title, saveLabel });
}

function activate(context) {
  const build = vscode.commands.registerCommand('exme.buildFile', async () => {
    const editor = await currentExmeEditor();
    if (!editor) return;
    const save = await chooseOutput('Choose the exact EXME output file', 'Build EXME');
    if (!save) return;
    const terminal = vscode.window.createTerminal('EXME');
    terminal.show(true);
    terminal.sendText(`${compilerCommand()} ${q(editor.document.fileName)} -o ${q(save.fsPath)}`);
  });

  const run = vscode.commands.registerCommand('exme.runFile', async () => {
    const editor = await currentExmeEditor();
    if (!editor) return;
    const save = await chooseOutput('Choose the exact EXME executable output file', 'Compile and Run');
    if (!save) return;
    const src = editor.document.fileName;
    const out = save.fsPath;
    const terminal = vscode.window.createTerminal('EXME');
    terminal.show(true);
    if (process.platform === 'win32') {
      terminal.sendText(`${compilerCommand()} ${q(src)} -o ${q(out)} && ${q(out)}`);
    } else {
      terminal.sendText(`${compilerCommand()} ${q(src)} -o ${q(out)} && chmod +x ${q(out)} && ${q(out)}`);
    }
  });

  context.subscriptions.push(build, run);
}

function deactivate() {}
module.exports = { activate, deactivate };
