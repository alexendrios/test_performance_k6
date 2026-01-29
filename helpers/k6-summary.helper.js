// helpers/k6-summary.helper.js
import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

export function buildSummary({ data, reportName, testName }) {
  const BUILD_DATE = new Date().toLocaleString('pt-BR');

  return {
    [`./reports/${reportName}.html`]: htmlReport(data, {
      title: `${testName} | ${BUILD_DATE} | Alexandre Santos`,
      theme: 'dark',
    }),
    stdout: textSummary(data, {
      indent: ' ',
      enableColors: true,
    }),
  };
}
