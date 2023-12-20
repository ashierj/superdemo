import { uniqueId } from 'lodash';

const CALLBACK_NAME = '_initArkoseLabsScript_callback_';

const getCallbackName = () => uniqueId(CALLBACK_NAME);

export const initArkoseLabsScript = ({ publicKey, domain }) => {
  const callbackFunctionName = getCallbackName();

  return new Promise((resolve, reject) => {
    window[callbackFunctionName] = (enforcement) => {
      delete window[callbackFunctionName];
      resolve(enforcement);
    };

    // in case the challenge needs to be loaded twice in the same Vue app, such as phone verification
    const element = document.getElementById('arkose-challenge-script');
    if (element) element.remove();

    const tag = document.createElement('script');
    [
      ['type', 'text/javascript'],
      ['src', `https://${domain}/v2/${publicKey}/api.js`],
      ['data-callback', callbackFunctionName],
      ['id', 'arkose-challenge-script'],
    ].forEach(([attr, value]) => {
      tag.setAttribute(attr, value);
    });

    tag.onerror = (error) => {
      reject(error);
    };

    document.head.appendChild(tag);
  });
};
