local heading_colors = {
  [1] = "BrandBlue",
  [2] = "BrandTeal",
  [3] = "SoftGray"
}

function Header(element)
  local color = heading_colors[element.level] or "SoftGray"
  table.insert(element.content, 1, pandoc.RawInline("latex", "\\color{" .. color .. "}"))
  return element
end
