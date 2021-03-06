
#region files

$GIT_IGNORE = '/node_modules/
/dist/*
!/dist/index.html
';

$DEV_SERVER_JS = '
var express = require("express");
var app = express();
var path = require("path");

app.get("/*.*", function(req, res) {
    const requestedFile = `./dist/${
        req.path.split("/")[req.path.split("/").length - 1]
    }`;
    console.log(`serving file: "${requestedFile}"`);
    res.sendFile(path.resolve(__dirname, requestedFile));
});

// viewed at http://localhost:8080
app.get("/*", function(req, res) {
    res.sendFile(path.resolve(__dirname, "dist/index.html"));
});

app.listen(8080);
';

$TASKS_JSON = '{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "webpack: watch",
            "type": "shell",
            "command": "webpack --watch"
        },
        {
            "label": "webpack: build",
            "type": "shell",
            "command": "webpack"
        },
        {
            "label": "browser-sync: watch",
            "type": "shell",
            "command": "browser-sync start --proxy http://localhost:8080 --ignore ./node_modules/ --files ./dist/",
            "options": {
                "cwd": "./"
            }
        },
        {
            "label": "express: start node server",
            "type": "shell",
            "command": "node ./devServer.js",
            "problemMatcher": []
        },
        {
            "label": "start dev server",
            "dependsOn": [
                "webpack: watch",
                "express: start node server",
                "browser-sync: watch"
            ]
        }
    ]
}
';

$INDEX_JS = 'import React from "react";
import ReactDOM from "react-dom";
import { App } from "./App.jsx";

ReactDOM.render(<App />, document.querySelector("#app"));
';

$APP_JSX = 'import React from "react";
import "./app.scss";

export const App = props => {
    return <h1>Hello world</h1>;
};

';

$INDEX_HTML = '<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta http-equiv="X-UA-Compatible" content="ie=edge" />
        <title>Template Project | Home</title>
    </head>
    <body>
        <div id="app"></div>

        <script src="/dist/bundle.js"></script>
    </body>
</html>
';

$APP_SCSS = 'h1 {
    font-style: italic;
}
'
$WEBPACK_CONFIG = '"use strict";

const path = require("path");

module.exports = {
    entry: "./src/index.js",
    context: path.resolve(__dirname),
    output: {
        path: path.resolve(__dirname, "dist"),
        filename: "bundle.js",
        publicPath: "/"
    },
    module: {
        rules: [
            {
                test: /\.(js|jsx)$/,
                exclude: /node_modules/,
                use: {
                    loader: "babel-loader"
                }
            },
            {
                test: /\.(ts|tsx)$/,
                exclude: /node_modules/,
                use: [
                    {
                        loader: "ts-loader"
                    }
                ]
            },
            {
                test: /\.(png|svg|jpg|gif)$/,
                use: ["file-loader"]
            },
            {
                test: /\.(png|svg|jpg|gif)$/,
                loader: "image-webpack-loader",
                enforce: "pre"
            },
            {
                test: /\.scss$/i,
                use: ["style-loader", "css-loader", "sass-loader"]
            }
        ]
    },
    mode: "development",
    resolve: {},
    devtool: "source-map",
    plugins: []
};
';

$BABEL_RC = '{
    "presets": ["@babel/preset-env", "@babel/preset-react"]
}
';

#endregion

function New-ReactProject {
    Param(
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $false)][switch]$SkipNpmInstall
    )

    # project directory
    $projectDirectory = New-Item -Path $ProjectName -ItemType Directory
    Set-Location $projectDirectory

    # npm packages
    npm init -y

    if (-not $SkipNpmInstall) {
        # dependencies
        npm i react react-dom

        # dev dependencies
        npm i @babel/core @babel/preset-env @babel/preset-react babel-loader webpack sass-loader node-sass css-loader style-loader typescript ts-loader source-map-loader image-webpack-loader css-loader @types/react-dom @types/react @types/react-router-dom express --save-dev
    }

    # config files
    New-Item -Path "./webpack.config.js" -ItemType File -Value $WEBPACK_CONFIG
    New-Item -Path "./.babelrc" -ItemType File -Value $BABEL_RC

    # .vscode
    $vsCodeDirectory = New-Item -Path "./.vscode" -ItemType Directory
    Set-Location $vsCodeDirectory
    New-Item -Path "./tasks.json" -ItemType File -Value $TASKS_JSON
    Set-Location ..


    # root directory
    New-Item -Path "./devServer.js" -ItemType File -Value $DEV_SERVER_JS

    # src directory
    $srcDirectory = New-Item -Path "./src" -ItemType Directory
    Set-Location $srcDirectory
    New-Item -Path "./App.jsx" -ItemType File -Value $APP_JSX
    New-Item -Path "./app.scss" -ItemType File -Value $APP_SCSS
    New-Item -Path "./index.js" -ItemType File -Value $INDEX_JS
    Set-Location ..

    # dist directory
    $distDirectory = New-Item -Path "./dist" -ItemType Directory
    Set-Location $distDirectory
    New-Item -Path "./index.html" -ItemType File -Value $INDEX_HTML
    Set-Location ..

    # git
    New-Item -Path "./.gitignore" -ItemType File -Value $GIT_IGNORE
    git init
    git add .
    git commit -m "initial commit"

    # done
    Write-Host "`n" -BackgroundColor Green
    Write-Host ""
    Write-Host "All done!" -ForegroundColor Green
    Write-Host "1. open vscode here" -ForegroundColor Green
    Write-Host "2. run task 'start dev server'" -ForegroundColor Green
    Write-Host "3. go to http://localhost:8080" -ForegroundColor Green
    Write-Host "`n" -BackgroundColor Green
    Write-Host ""

}

<#
.SYNOPSIS
Modify a base create react app template with the some basic customisations. This only works for projects using the typescript template

The idea behind this one is that it's much easier to modify a generated create-react-app instead of writing my own generator

#>
function Update-CreateReactAppTemplate {

    Write-Host "Modifying tsconfig..." -ForegroundColor Cyan
    $tsConfigPath = "./tsconfig.json"
    Write-Host " Setting baseUrl"
    $tsConfig = Get-Content -Raw -Path $tsConfigPath | ConvertFrom-Json
    $tsConfig.compilerOptions | Add-Member -Name "baseUrl" -Value "src/" -MemberType NoteProperty
    ConvertTo-Json $tsConfig -Depth 4  | Out-File $tsConfigPath

    Write-Host "Removing base CSS..." -ForegroundColor Cyan
    $cssFiles = @(
        @{
            css = "./src/App.css";
            importedBy = ".\src\App.tsx";
            importPath = "./App.css"
        },
        @{
            css = "./src/index.css";
            importedBy = ".\src\Index.tsx";
            importPath = "./index.css"
        }
    )
    foreach ($cssFile in $cssFiles){
        Write-Host " Removing $($cssFile.css)"
        if (Test-Path $cssFile.css){
            Remove-Item $cssFile.css
        }
        $newContent = Get-Content $cssFile.importedBy | % { if ($_ -eq "import '$($cssFile.importPath)';") { return } else { return $_ } };
        Set-Content -Path $cssFile.importedBy -Value $newContent
    }

    Write-Host "Adding node_modules..." -ForegroundColor Cyan
    Write-Host " node-sass"
    npm install node-sass

    Write-Host "Finished" -ForegroundColor Green
}

<#
.SYNOPSIS
Create a new typescript react component folder.

.PARAMETER ComponentName
The name of the component you wish to create.

.EXAMPLE
New-ReactComponent menu

.NOTES
Component folders will always be created under `./src/components/` directory
#>

function New-ReactComponent {
    param (
        [string] $ComponentName
    )

    $sanitisedComponentName = $ComponentName.Replace("/", "").Replace(" ", "-")

    $reactFilename = "$sanitisedComponentName.tsx"
    $scssFilename = "$sanitisedComponentName.scss"
    $lowerCaseComponentName = $sanitisedComponentName.ToLower()

    $componentFilepath = "./src/components/$sanitisedComponentName";

    $indexContents = "export * from './$ComponentName'"

    $scssContents = ".$lowerCaseComponentName { }"

    $reactContents = @"
import React from "react";
import "./$scssFilename";

interface ${ComponentName}Props {

}

export const ${ComponentName} = (props : ${ComponentName}Props) => {
    return <div className="$lowerCaseComponentName">

    </div>
}

"@;

    New-Item $componentFilepath -Type Directory -ErrorAction Ignore | Out-Null

    New-Item (Join-Path $componentFilepath $reactFilename) -Type File -Value $reactContents | Out-Null
    New-Item (Join-Path $componentFilepath $scssFilename) -Type File -Value $scssContents | Out-Null
    New-Item (Join-Path $componentFilepath "index.ts") -Type File -Value $indexContents | Out-Null

    Write-Host "Created component: $sanitisedComponentName" -ForegroundColor Green
    Write-Host "  $componentFilepath" -ForegroundColor Green
    Write-Host "    |- $reactFilename" -ForegroundColor Cyan
    Write-Host "    |- $scssFilename" -ForegroundColor DarkYellow
    Write-Host "    |- index.ts" -ForegroundColor Cyan
}


#Alias
New-Alias -Name nrc -Value New-ReactComponent

#Exports
Export-ModuleMember New-ReactProject
Export-ModuleMember New-ReactComponent
Export-ModuleMember Update-CreateReactAppTemplate
Export-ModuleMember -Alias *
