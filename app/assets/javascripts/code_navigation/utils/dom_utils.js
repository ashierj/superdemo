const TEXT_NODE = 3;

const isTextNode = ({ nodeType }) => nodeType === TEXT_NODE;

const isBlank = (str) => !str || /^\s*$/.test(str);

const isMatch = (s1, s2) => !isBlank(s1) && s1.trim() === s2.trim();

const createSpan = (content, classList) => {
  const span = document.createElement('span');
  span.innerText = content;
  span.classList = classList || '';
  return span;
};

const wrapSpacesWithSpans = (text) =>
  text.replace(/ /g, createSpan(' ').outerHTML).replace(/\t/g, createSpan('	').outerHTML);

const wrapTextWithSpan = (el, text, classList) => {
  if (isTextNode(el) && isMatch(el.textContent, text)) {
    const newEl = createSpan(text.trim(), classList);
    el.replaceWith(newEl);
  }
};

const wrapNodes = (text, classList) => {
  const wrapper = createSpan();
  // eslint-disable-next-line no-unsanitized/property
  wrapper.innerHTML = wrapSpacesWithSpans(text);
  wrapper.childNodes.forEach((el) => wrapTextWithSpan(el, text, classList));
  return wrapper.childNodes;
};

export { wrapNodes, isTextNode };
