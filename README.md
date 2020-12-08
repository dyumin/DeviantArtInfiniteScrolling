# DeviantArtInfiniteScrolling

Из известных багов:

UITableView после insertRows(at indexPaths: [IndexPath], ...) в tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) спрашивает cell не для текущего ряда, а для ~10 следующих. Это вводит в заблуждение логику загрузки картинок и она грузит следующие 10, а только потом текущие. 

Можно словить [LayoutConstraints] Unable to simultaneously satisfy constraints. при быстром скролле.
