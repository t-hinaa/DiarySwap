import { onMounted, onUnmounted, ref } from "vue";

export function useJello(options = {}) {
    const {
        stiffness = 0.12,   // バネの強さ
        damping = 0.79,      // 揺れの収まり具合（小さいほど余韻が残る）
        enterScaleX = 1.06,  // ホバー時の横の広がり
        enterScaleY = 0.94,  // ホバー時の縦のつぶれ
        rotStrength = 3,     // 傾きの強さ（度）
    } = options;

    const elRef = ref(null);
    const transformStyle = ref("scale(1, 1) rotate(0deg)");

    let scaleX = 1, scaleY = 1, rotateDeg = 0;
    let velX = 0, velY = 0, velRot = 0;
    let goalScaleX = 1, goalScaleY = 1, goalRot = 0;
    let rafId = null;

    const onPointerEnter = (e) => {
        const el = elRef.value;
        if (!el) return;
        const rect = el.getBoundingClientRect();
        const relX = (e.clientX - rect.left) / rect.width - 0.5;

        goalScaleX = enterScaleX;
        goalScaleY = enterScaleY;
        goalRot = relX * rotStrength * 1.4;
        velX += relX >= 0 ? 0.045 : -0.045;
        velY -= 0.04;
        velRot += relX * 1.6;
    };

    const onPointerMove = (e) => {
        const el = elRef.value;
        if (!el) return;
        const rect = el.getBoundingClientRect();
        const relX = (e.clientX - rect.left) / rect.width - 0.5;
        const relY = (e.clientY - rect.top) / rect.height - 0.5;

        goalScaleX = 1 + Math.abs(relX) * 0.07;
        goalScaleY = 1 - Math.abs(relY) * 0.055;
        goalRot = relX * rotStrength;
    };

    const onPointerLeave = () => {
        goalScaleX = 1;
        goalScaleY = 1;
        goalRot = 0;
        velX += 0.04;
        velY -= 0.04;
    };

    const onPointerDown = () => {
        velY += 0.05;
        velX -= 0.03;
    };

    const loop = () => {
        velX = (velX + (goalScaleX - scaleX) * stiffness) * damping;
        velY = (velY + (goalScaleY - scaleY) * stiffness) * damping;
        velRot = (velRot + (goalRot - rotateDeg) * stiffness) * damping;

        scaleX += velX;
        scaleY += velY;
        rotateDeg += velRot;

        transformStyle.value = `scale(${scaleX.toFixed(4)}, ${scaleY.toFixed(4)}) rotate(${rotateDeg.toFixed(2)}deg)`;
        rafId = requestAnimationFrame(loop);
    };

    onMounted(() => {
        const el = elRef.value;
        if (!el) return;
        el.addEventListener("pointerenter", onPointerEnter);
        el.addEventListener("pointermove", onPointerMove);
        el.addEventListener("pointerleave", onPointerLeave);
        el.addEventListener("pointerdown", onPointerDown);
        rafId = requestAnimationFrame(loop);
    });

    onUnmounted(() => {
        const el = elRef.value;
        if (el) {
            el.removeEventListener("pointerenter", onPointerEnter);
            el.removeEventListener("pointermove", onPointerMove);
            el.removeEventListener("pointerleave", onPointerLeave);
            el.removeEventListener("pointerdown", onPointerDown);
        }
        if (rafId) cancelAnimationFrame(rafId);
    });

    return {
        elRef,
        transformStyle,
    };
}