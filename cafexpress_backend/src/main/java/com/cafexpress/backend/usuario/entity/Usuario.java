package com.cafexpress.backend.usuario.entity;

import com.cafexpress.backend.usuario.enums.Rol;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "usuarios")
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(nullable = false, unique = true, length = 254)
    private String email;

    @Column(length = 30)
    private String username;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Rol rol;

    @Column(name = "empresa_productor", length = 120)
    private String empresaProductor;

    @Column(name = "pais_origen", length = 80)
    private String paisOrigen;

    @Column(nullable = false)
    private boolean activo = true;

    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    protected Usuario() {
    }

    public Usuario(String nombre, String email, String passwordHash, Rol rol) {
        this.nombre = nombre;
        this.email = email;
        this.passwordHash = passwordHash;
        this.rol = rol;
    }

    @PrePersist
    void antesDeGuardar() {
        creadoEn = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public String getNombre() {
        return nombre;
    }

    public String getUsername() { return username; }

    public void asignarUsername(String username) { this.username = username; }

    public String getEmail() {
        return email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public Rol getRol() {
        return rol;
    }

    public boolean isActivo() {
        return activo;
    }

    public String getEmpresaProductor() { return empresaProductor; }
    public String getPaisOrigen() { return paisOrigen; }

    public void completarPerfil(String nombre, String empresaProductor, String paisOrigen) {
        this.nombre = nombre.strip();
        this.empresaProductor = empresaProductor.strip();
        this.paisOrigen = paisOrigen.strip();
    }

    public Instant getCreadoEn() {
        return creadoEn;
    }
}
