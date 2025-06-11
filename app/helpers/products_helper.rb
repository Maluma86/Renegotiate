module ProductsHelper
  def sort_link(column, label)
    direction = (params[:sort] == column && params[:direction] == "asc") ? "desc" : "asc"
    icon = sort_icon(column)

    link_to "#{label} #{icon}".html_safe, products_path(params.permit!.merge(sort: column, direction: direction))
  end

  def sort_icon(column)
    return "" unless params[:sort] == column

    params[:direction] == "asc" ? "↑" : "↓"
  end
end
