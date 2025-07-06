document.addEventListener('DOMContentLoaded', function() {
    const codeBlocks = document.querySelectorAll('pre code, .highlight code');
    
    codeBlocks.forEach(function(codeBlock) {
        const copyButton = document.createElement('button');
        copyButton.className = 'copy-code-btn';
        copyButton.innerHTML = 'Copy';
        copyButton.setAttribute('aria-label', 'Copy code to clipboard');
        
        const parent = codeBlock.closest('pre') || codeBlock.closest('.highlight');
        if (parent) {
            const wrapper = document.createElement('div');
            wrapper.className = 'code-block-wrapper';
            
            parent.parentNode.insertBefore(wrapper, parent);
            
            wrapper.appendChild(parent);
            wrapper.appendChild(copyButton);
        }
        
        copyButton.addEventListener('click', function() {
            const codeText = codeBlock.textContent || codeBlock.innerText;
            
            if (navigator.clipboard) {
                navigator.clipboard.writeText(codeText).then(function() {
                    showCopyFeedback(copyButton, 'Copied!');
                }).catch(function() {
                    fallbackCopyTextToClipboard(codeText, copyButton);
                });
            } else {
                fallbackCopyTextToClipboard(codeText, copyButton);
            }
        });
    });
});

function fallbackCopyTextToClipboard(text, button) {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    textArea.style.top = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    
    try {
        const successful = document.execCommand('copy');
        if (successful) {
            showCopyFeedback(button, 'Copied!');
        } else {
            showCopyFeedback(button, 'Failed to copy');
        }
    } catch (err) {
        showCopyFeedback(button, 'Failed to copy');
    }
    
    document.body.removeChild(textArea);
}

function showCopyFeedback(button, message) {
    const originalText = button.innerHTML;
    button.innerHTML = message;
    button.classList.add('copied');
    
    setTimeout(function() {
        button.innerHTML = originalText;
        button.classList.remove('copied');
    }, 2000);
}
