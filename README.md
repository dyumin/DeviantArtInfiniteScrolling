# DeviantArtInfiniteScrolling

Тк эндпоинты с картинками доступны из РФ нестабильно, лучше запускать с VPN

Из известных багов:

UITableView на первом insertRows(at indexPaths: [IndexPath], ...) в tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) спрашивает cell не для текущего ряда, а для ~10 следующих. Это вводит в заблуждение логику загрузки картинок и она грузит следующие 10, а только потом текущие.
https://stackoverflow.com/questions/6077885/insertrowsatindexpaths-calling-cellforrowatindexpath-for-every-row 

Можно словить [LayoutConstraints] Unable to simultaneously satisfy constraints. при быстром скролле.
