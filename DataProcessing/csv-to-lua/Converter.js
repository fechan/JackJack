const fs = require('fs');
const CSVParser = require('./CSVParser.js');
const DataGridRenderer = require('./DataGridRenderer.js');

const csvFilePath = process.argv[2]; // get csv filepath from command line
const csvExtensionlessName = csvFilePath.substring(0, csvFilePath.length - 4);
const converterName = process.argv[3];
const inputText = require('fs').readFileSync(csvFilePath, 'utf8'); // load it as text

let parseOutput = CSVParser.parse(
    inputText, // input
    "comma", // delimiterType
    "dot", // decimalSign
    true, // headersIncluded
    true, // safeHeaders
    false, // downcaseHeaders
    false, // upcaseHeaders
    "\n"
  ); // rowDelimiter
let dataGrid = parseOutput.dataGrid;
let headerNames = parseOutput.headerNames;
let headerTypes = parseOutput.headerTypes;
let errors = parseOutput.errors;

let outputText = DataGridRenderer[converterName](dataGrid, headerNames, headerTypes, "\t", "\n");

// add header to output
const header = `local addonName, addon = ...

addon.${csvExtensionlessName} = `;
outputText = header + outputText;

// write output to file
fs.writeFileSync(csvExtensionlessName + ".lua", outputText);