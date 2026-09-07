const vscode = require('vscode');
const path = require('path');
const fs = require('fs');

function q(s) { return '"' + s.replace(/"/g, '\\"') + '"'; }

function activate(context) {
  const run = vscode.commands.registerCommand('exme.runFile', async () => {
    const editor = vscode.window.activeTextEditor;
    if (!editor || !editor.document.fileName.toLowerCase().endsWith('.exme')) {
      vscode.window.showErrorMessage('Open an .exme file first.');
      return;
    }
    await editor.document.save();

    const folders = vscode.workspace.workspaceFolders;
    if (!folders || folders.length === 0) {
      vscode.window.showErrorMessage('Open the EXME project folder in VS Code first.');
      return;
    }

    const root = folders[0].uri.fsPath;
    const windows = process.platform === 'win32';
    const compiler = path.join(root, 'compiler', windows ? 'exme.exe' : 'exme');
    if (!fs.existsSync(compiler)) {
      vscode.window.showErrorMessage('Build the EXME compiler first from compiler/exme_build_windows.bat or compiler/exme_build_linux.sh.');
      return;
    }

    const save = await vscode.window.showSaveDialog({
      title: 'Choose the exact EXME output file',
      saveLabel: 'Compile and Run'
    });
    if (!save) return;

    const src = editor.document.fileName;
    const out = save.fsPath;
    const terminal = vscode.window.createTerminal('EXME');
    terminal.show(true);
    if (windows) {
      terminal.sendText(`${q(compiler)} ${q(src)} -o ${q(out)} && ${q(out)}`);
    } else {
      terminal.sendText(`${q(compiler)} ${q(src)} -o ${q(out)} && chmod +x ${q(out)} && ${q(out)}`);
    }
  });
  context.subscriptions.push(run);
}

function deactivate() {}
module.exports = { activate, deactivate };
