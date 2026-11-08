package com.cafexpress.backend.usuario.repository;

import com.cafexpress.backend.usuario.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UsuarioRepository extends JpaRepository<Usuario, UUID> {

    Optional<Usuario> findByEmail(String email);

    Optional<Usuario> findByUsername(String username);
    boolean existsByUsername(String username);

    boolean existsByEmail(String email);
}