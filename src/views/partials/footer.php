<script src="leaflet/leaflet.js"></script>
<script>
var map = L.map('map', { attributionControl: false }).setView([52.6088, 39.5994], 12);
L.tileLayer('https://tile.openstreetmap.de/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(map);
var marker = null;
map.on('click', function(e) {
    var lat = e.latlng.lat, lng = e.latlng.lng;
    if (marker) { marker.setLatLng(e.latlng); } else { marker = L.marker(e.latlng).addTo(map); }
    fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lng + '&accept-language=ru')
        .then(function(r) { return r.json(); })
        .then(function(data) {
            var addr = '', a = data.address;
            if (a.road) addr += a.road;
            if (a.house_number) addr += ', ' + a.house_number;
            if (a.city || a.town || a.village) addr += ', ' + (a.city || a.town || a.village);
            document.getElementById('address').value = addr || data.display_name;
            marker.bindPopup(addr || data.display_name).openPopup();
        })
        .catch(function() {
            document.getElementById('address').value = lat.toFixed(5) + ', ' + lng.toFixed(5);
        });
});

var cart = [];
function addToCart(id, name, price) {
    var size = document.getElementById('size-' + id).value;
    var qty  = parseInt(document.getElementById('qty-' + id).value);
    if (isNaN(qty) || qty < 1) qty = 1;
    var existing = cart.find(function(i) { return i.id === id && i.size === size; });
    if (existing) { existing.qty = qty; } else { cart.push({ id: id, name: name, size: size, qty: qty, price: price }); }
    document.getElementById('card-' + id).classList.add('selected');
    var btn = document.querySelector('#card-' + id + ' .btn-add-cart');
    btn.textContent = '✓ В корзине';
    btn.classList.add('in-cart');
    renderCart();
}
function removeFromCart(index) {
    var item = cart[index];
    cart.splice(index, 1);
    var stillInCart = cart.find(function(i) { return i.id === item.id; });
    if (!stillInCart) {
        var card = document.getElementById('card-' + item.id);
        if (card) { card.classList.remove('selected'); var btn = card.querySelector('.btn-add-cart'); btn.textContent = 'В корзину'; btn.classList.remove('in-cart'); }
    }
    renderCart();
}
function renderCart() {
    var list = document.getElementById('cart-list');
    var total = document.getElementById('cart-total');
    var sum = document.getElementById('cart-total-sum');
    if (cart.length === 0) {
        list.innerHTML = '<li><span class="cart-empty-msg">Корзина пуста — выберите товары выше</span></li>';
        total.style.display = 'none'; return;
    }
    var totalSum = 0; list.innerHTML = '';
    cart.forEach(function(item, index) {
        var itemSum = item.price * item.qty; totalSum += itemSum;
        var li = document.createElement('li');
        li.innerHTML = '<span>' + item.name + ' / ' + item.size + ' / ' + item.qty + ' шт.</span>' +
            '<span><b>' + itemSum.toLocaleString('ru-RU') + ' ₽</b>' +
            '<button class="cart-remove" onclick="removeFromCart(' + index + ')" title="Удалить">✕</button></span>';
        list.appendChild(li);
    });
    sum.textContent = totalSum.toLocaleString('ru-RU');
    total.style.display = 'block';
}
function injectCartItems() {
    if (cart.length === 0) { alert('Добавьте хотя бы один товар в корзину!'); window.scrollTo({ top: 0, behavior: 'smooth' }); return false; }
    var container = document.getElementById('cart-hidden-inputs');
    container.innerHTML = '';
    var totalSum = 0;
    cart.forEach(function(item) {
        totalSum += item.price * item.qty;
        function hidden(name, value) { var input = document.createElement('input'); input.type = 'hidden'; input.name = name; input.value = value; container.appendChild(input); }
        hidden('category[]', item.name); hidden('size[]', item.size); hidden('quantity[]', item.qty);
    });
    var ti = document.createElement('input'); ti.type = 'hidden'; ti.name = 'total_sum'; ti.value = totalSum; container.appendChild(ti);
    return true;
}
</script>
</body>
</html>
