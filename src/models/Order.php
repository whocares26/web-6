<?php
namespace App;

use Doctrine\ORM\Mapping as ORM;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;

#[ORM\Entity]
#[ORM\Table(name: 'orders')]
class Order
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private int $id;

    #[ORM\ManyToOne(targetEntity: User::class, inversedBy: 'orders')]
    #[ORM\JoinColumn(name: 'user_id', referencedColumnName: 'id', nullable: true)]
    private ?User $user = null;

    #[ORM\Column(length: 100)]
    private string $first_name;

    #[ORM\Column(length: 100)]
    private string $last_name;

    #[ORM\Column(length: 50)]
    private string $phone;

    #[ORM\Column(length: 100)]
    private string $city;

    #[ORM\Column(length: 255)]
    private string $address;

    #[ORM\Column(length: 100)]
    private string $delivery;

    #[ORM\Column(length: 100)]
    private string $payment;

    #[ORM\Column(type: 'bigint')]
    private int $total_sum = 0;

    #[ORM\Column(type: 'datetime')]
    private \DateTime $created_at;

    #[ORM\OneToMany(targetEntity: OrderItem::class, mappedBy: 'order')]
    private Collection $items;

    public function __construct()
    {
        $this->items = new ArrayCollection();
        $this->created_at = new \DateTime();
    }

    public function getId(): int              { return $this->id; }
    public function getUser(): ?User          { return $this->user; }
    public function getFirstName(): string    { return $this->first_name; }
    public function getLastName(): string     { return $this->last_name; }
    public function getPhone(): string        { return $this->phone; }
    public function getCity(): string         { return $this->city; }
    public function getAddress(): string      { return $this->address; }
    public function getDelivery(): string     { return $this->delivery; }
    public function getPayment(): string      { return $this->payment; }
    public function getTotalSum(): int        { return $this->total_sum; }
    public function getCreatedAt(): \DateTime { return $this->created_at; }
    public function getItems(): Collection   { return $this->items; }

    public function setUser(?User $v): self       { $this->user       = $v; return $this; }
    public function setFirstName(string $v): self { $this->first_name = $v; return $this; }
    public function setLastName(string $v): self  { $this->last_name  = $v; return $this; }
    public function setPhone(string $v): self     { $this->phone      = $v; return $this; }
    public function setCity(string $v): self      { $this->city       = $v; return $this; }
    public function setAddress(string $v): self   { $this->address    = $v; return $this; }
    public function setDelivery(string $v): self  { $this->delivery   = $v; return $this; }
    public function setPayment(string $v): self   { $this->payment    = $v; return $this; }
    public function setTotalSum(int $v): self     { $this->total_sum  = $v; return $this; }
}
