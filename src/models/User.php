<?php
namespace App;

use Doctrine\ORM\Mapping as ORM;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;

#[ORM\Entity]
#[ORM\Table(name: 'users')]
class User
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private int $id;

    #[ORM\Column(length: 100, unique: true)]
    private string $username;

    #[ORM\Column(length: 255, unique: true)]
    private string $email;

    #[ORM\Column(length: 255)]
    private string $password;

    #[ORM\Column(length: 20)]
    private string $role = 'user';

    #[ORM\Column(type: 'datetime')]
    private \DateTime $created_at;

    #[ORM\OneToMany(targetEntity: Order::class, mappedBy: 'user')]
    private Collection $orders;

    public function __construct()
    {
        $this->created_at = new \DateTime();
        $this->orders = new ArrayCollection();
    }

    public function getId(): int              { return $this->id; }
    public function getUsername(): string     { return $this->username; }
    public function getEmail(): string        { return $this->email; }
    public function getPassword(): string     { return $this->password; }
    public function getRole(): string         { return $this->role; }
    public function getCreatedAt(): \DateTime { return $this->created_at; }
    public function getOrders(): Collection  { return $this->orders; }

    public function setUsername(string $v): self { $this->username = $v; return $this; }
    public function setEmail(string $v): self    { $this->email    = $v; return $this; }
    public function setPassword(string $v): self { $this->password = $v; return $this; }
    public function setRole(string $v): self     { $this->role     = $v; return $this; }
}
