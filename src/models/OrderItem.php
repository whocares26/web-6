<?php
namespace App;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
#[ORM\Table(name: 'order_items')]
class OrderItem
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private int $id;

    #[ORM\ManyToOne(targetEntity: Order::class, inversedBy: 'items')]
    #[ORM\JoinColumn(name: 'order_id', referencedColumnName: 'id')]
    private Order $order;

    #[ORM\Column(length: 255)]
    private string $category;

    #[ORM\Column(length: 50)]
    private string $size;

    #[ORM\Column]
    private int $quantity;

    public function getId(): int        { return $this->id; }
    public function getOrder(): Order   { return $this->order; }
    public function getCategory(): string { return $this->category; }
    public function getSize(): string   { return $this->size; }
    public function getQuantity(): int  { return $this->quantity; }

    public function setOrder(Order $v): self     { $this->order    = $v; return $this; }
    public function setCategory(string $v): self { $this->category = $v; return $this; }
    public function setSize(string $v): self     { $this->size     = $v; return $this; }
    public function setQuantity(int $v): self    { $this->quantity = $v; return $this; }
}
