// Initialize FlexSearch
let searchIndex;
const resList = document.getElementById('searchResults');
const sInput = document.getElementById('searchInput');
let resultsAvailable = false;

// Load the search index on window load
window.onload = async function () {
    try {
        const response = await fetch('../index.json');
        if (!response.ok) throw new Error(`HTTP error! Status: ${response.status}`);
        const data = await response.json();

        // Initialize FlexSearch index
        searchIndex = new FlexSearch.Document({
            document: {
                id: 'permalink',
                index: ['title', 'content'],
                store: ['title', 'content', 'permalink', 'summary']
            },
            tokenize: 'forward',
            cache: true
        });

        // Add documents to index
        data.forEach((doc, idx) => {
            searchIndex.add({
                ...doc,
                id: idx
            });
        });
    } catch (error) {
        console.error('Error loading search index:', error);
    }
};

function findMatchPosition(text, query) {
    const textLower = text.toLowerCase();
    const queryLower = query.toLowerCase();

    // Try exact phrase first
    let position = textLower.indexOf(queryLower);

    // If not found, try individual words
    if (position === -1) {
        const words = queryLower.split(/\s+/).filter(word => word.length >= 2);
        for (const word of words) {
            position = textLower.indexOf(word);
            if (position !== -1) break;
        }
    }

    return position;
}

function getPreview(content, query) {
    if (!content || !query) return '';

    const position = findMatchPosition(content, query);
    if (position === -1) return '';

    // Find the start of the line containing the match
    let lineStart = position;
    // Search backwards to find line start
    while (lineStart > 0 && content[lineStart - 1] !== '\n') {
        lineStart--;
    }

    // Find the end of the line containing the match
    let lineEnd = position;
    // Search forwards to find line end
    while (lineEnd < content.length && content[lineEnd] !== '\n') {
        lineEnd++;
    }

    // Get some surrounding lines
    let contextStart = lineStart;
    let contextEnd = lineEnd;

    // Add one line before if available
    let prevLineStart = content.lastIndexOf('\n', lineStart - 1);
    if (prevLineStart !== -1) {
        contextStart = prevLineStart + 1;
    }

    // Add one line after if available
    let nextLineEnd = content.indexOf('\n', lineEnd + 1);
    if (nextLineEnd !== -1) {
        contextEnd = nextLineEnd;
    }

    let preview = content.substring(contextStart, contextEnd);

    // Add ellipsis if needed
    if (contextStart > 0) preview = '...' + preview;
    if (contextEnd < content.length) preview += '...';

    return preview;
}

function highlightMatches(text, query) {
    if (!text || !query) return text;

    // First try to highlight the exact phrase
    const exactRegex = new RegExp(`(${escapeRegExp(query)})`, 'gi');
    let result = text.replace(exactRegex, '<mark>$1</mark>');

    // If no exact matches, try individual words
    if (!result.includes('<mark>')) {
        const words = query.split(/\s+/)
            .filter(word => word.length >= 2)
            .map(word => escapeRegExp(word))
            .sort((a, b) => b.length - a.length);

        if (words.length > 0) {
            const regex = new RegExp(`(${words.join('|')})`, 'gi');
            result = text.replace(regex, '<mark>$1</mark>');
        }
    }

    return result;
}

function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Reset search results and input
function reset() {
    resultsAvailable = false;
    resList.innerHTML = '';
    sInput.value = '';
    sInput.focus();
}

// Handle search input with debouncing
let debounceTimeout;
sInput.addEventListener('input', () => {
    clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(async () => {
        const searchTerm = sInput.value.trim();
        if (!searchTerm) {
            reset();
            return;
        }

        // Perform search across all fields
        const titleResults = await searchIndex.searchAsync(searchTerm, {
            index: ['title'],
            limit: 5,
            enrich: true
        });
        const contentResults = await searchIndex.searchAsync(searchTerm, {
            index: ['content'],
            limit: 5,
            enrich: true
        });

        // Combine and deduplicate results
        const results = new Map();
        [titleResults, contentResults].flat().forEach(result => {
            result.result.forEach(item => {
                if (!results.has(item.doc.permalink)) {
                    results.set(item.doc.permalink, item.doc);
                }
            });
        });

        if (results.size === 0) {
            resList.innerHTML = '<li>No results found</li>';
            resultsAvailable = false;
            return;
        }

        const resultSet = Array.from(results.values()).map(doc => {
            const title = highlightMatches(doc.title, searchTerm);
            const preview = doc.content ?
                highlightMatches(getPreview(doc.content, searchTerm), searchTerm) :
                doc.summary;

            return `
                <li class="post-entry">
                    <header class="entry-header">
                        <h2>${title}</h2>
                    </header>
                    ${preview ? `<div class="entry-content"><p>${preview}</p></div>` : ''}
                    <a href="${doc.permalink}" aria-label="${doc.title}"></a>
                </li>
            `;
        }).join('');

        resList.innerHTML = resultSet;
        resultsAvailable = true;
    }, 300); // Adjust the debounce delay as needed
});

// Clear results when search is canceled
sInput.addEventListener('search', () => {
    if (!sInput.value) reset();
});

// Keyboard navigation for search results
document.addEventListener('keydown', (e) => {
    const { key } = e;
    const activeElement = document.activeElement;
    const isInSearchBox = document.getElementById('searchbox').contains(activeElement);

    if (key === 'Escape') {
        reset();
    } else if (!resultsAvailable || !isInSearchBox) {
        return;
    } else if (key === 'ArrowDown') {
        e.preventDefault();
        const firstLink = resList.querySelector('a');
        if (activeElement === sInput && firstLink) {
            firstLink.focus();
        } else if (activeElement.parentElement.nextElementSibling) {
            activeElement.parentElement.nextElementSibling.querySelector('a').focus();
        }
    } else if (key === 'ArrowUp') {
        e.preventDefault();
        if (activeElement.parentElement.previousElementSibling) {
            activeElement.parentElement.previousElementSibling.querySelector('a').focus();
        } else {
            sInput.focus();
        }
    } else if (key === 'ArrowRight' && activeElement.tagName === 'A') {
        activeElement.click();
    }
});
