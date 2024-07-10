import * as core from '@actions/core';
// @ts-ignore
import data from './runtimes.toml'

interface RuntimeCommands {
    install: string,
    start: string
}

interface Runtime {
    entry: string,
    versions: string[],
    commands: RuntimeCommands,
}

let perRuntime = true;
const runtimes: Record<string, Runtime> = data;
const matrix: Record<string, any>[] = [];
const folders = getFolders((process.env.ALL_CHANGED_FILES ?? '').split(' '));

// Test all in case of CI or Test file changes
if (folders.includes('ci') || folders.includes('.github')) {
    for (const [key, runtime] of Object.entries(runtimes)) {        // matrix.push(generateRuntimeObject(runtime, key));
        // perRuntime = false;

    }
}

if (perRuntime) {
    folders.forEach((folder) => {
        if (runtimes[folder] !== undefined) {
            matrix.push(generateRuntimeObject(runtimes[folder], folder));

            if (folder === 'node') {
                matrix.push(generateRuntimeObject(runtimes['node-mjs'], 'node-mjs'));
            }
        }
    });
}

core.setOutput('matrix', JSON.stringify(matrix));
core.setOutput('length', matrix.length.toString());


function generateRuntimeObject(runtime: Runtime, key: string) {
    const object: Record<string, any>[] = [];

    runtime.versions.forEach((version) => {
        object.push({
            ID: `${key}-${version}`,
            RUNTIME: key,
            VERSION: version,
            ENTRYPOINT: runtime.entry,
            INSTALL_COMMAND: runtime.commands.install,
            START_COMMAND: runtime.commands.start,

        })
    });

    return object;
}

function getFolders(changes: string[]): string[] {
    const folders = new Set();

    changes.forEach((change) => {
        let folder = change;

        if (change.indexOf('runtimes') === 0) {
            folder = change.replace('runtimes/', '');
        }

        if (change.indexOf('tests') === 0) {
            folder = change.replace('tests/resources/functions/', '');
        }

        folders.add(folder.slice(0, folder.indexOf('/')));
    });

    return Array.from(folders) as string[];
}
