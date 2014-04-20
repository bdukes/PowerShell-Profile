Set-StrictMode -Version Latest

function Write-HtmlNode($node, $indent = '') {
    Write-Host $indent -NoNewline
    if ($node.nodeName -eq '#text') {
        Write-Host $node.nodeValue -ForegroundColor Red
        return
    } elseif ($node.nodeName -eq '#comment') {
        Write-Host $node.OuterHtml -ForegroundColor DarkGreen
        return
    }
    Write-Host '<' -NoNewline -ForegroundColor Gray
    Write-Host $node.nodeName -NoNewline -ForegroundColor Blue
    foreach ($attr in ($node.attributes | ? { $_.Specified })) {
        Write-Host ' ' -NoNewline
        Write-Host $attr.name -NoNewline -ForegroundColor Magenta
        Write-Host '="' -NoNewline -ForegroundColor Gray
        Write-Host $attr.value -NoNewline -ForegroundColor Yellow
        Write-Host '"' -NoNewline -ForegroundColor Gray
    }
    if ($node.canHaveChildren -eq $false) {
        Write-Host ' />' -ForegroundColor Gray
        return
    }
    Write-Host '>' -ForegroundColor Gray
    $child = $node.firstChild
    $childIndent = $indent + '  '
    while ($child -ne $null) {
        write-htmlNode $child $childIndent
        $child = $child.nextSibling
    }
    Write-Host $indent -NoNewline
    Write-Host '</' -NoNewline -ForegroundColor Gray
    Write-Host $node.nodeName -NoNewline -ForegroundColor Blue
    Write-Host '>' -ForegroundColor Gray
<#
.SYNOPSIS
    Writes the given HTML node with color
.PARAMETER node
    An HTML node, probably from (Invoke-WebRequest $url).ParsedHtml.documentElement
.PARAMETER indent
    How much of an indent to add before the first node
#>
}

Export-ModuleMember Write-HtmlNode